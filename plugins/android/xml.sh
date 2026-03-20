#!/usr/bin/env bash

if [[ -z "${_ANDROID_XML_LOADED:-}" ]]; then
_ANDROID_XML_LOADED=1

declare -g ANDROID_XML_TOOL=""

android_xml_init() {
    if command_exists xmlstarlet; then
        ANDROID_XML_TOOL="xmlstarlet"
        output_debug "XML tool: xmlstarlet"
        return 0
    fi
    
    if command_exists xmllint; then
        ANDROID_XML_TOOL="xmllint"
        output_debug "XML tool: xmllint"
        return 0
    fi
    
    output_warning "$(android_i18n_get "xml_tool_not_found")"
    ANDROID_XML_TOOL="sed"
    return 1
}

android_xml_check_tool() {
    if [[ -z "${ANDROID_XML_TOOL:-}" ]]; then
        android_xml_init
    fi
    
    [[ "$ANDROID_XML_TOOL" != "sed" ]]
}

android_xml_read_attr() {
    local xml_file="$1"
    local xpath="$2"
    local attr="$3"
    local default="${4:-}"
    
    if [[ ! -f "$xml_file" ]]; then
        echo "$default"
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            local result
            result=$(xmlstarlet sel -t -v "${xpath}/@${attr}" "$xml_file" 2>/dev/null)
            if [[ -n "$result" ]]; then
                echo "$result"
                return 0
            fi
            ;;
        xmllint)
            local result
            result=$(xmllint --xpath "string(${xpath}/@${attr})" "$xml_file" 2>/dev/null)
            if [[ -n "$result" ]]; then
                echo "$result"
                return 0
            fi
            ;;
    esac
    
    echo "$default"
    return 1
}

android_xml_read_text() {
    local xml_file="$1"
    local xpath="$2"
    local default="${3:-}"
    
    if [[ ! -f "$xml_file" ]]; then
        echo "$default"
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            local result
            result=$(xmlstarlet sel -t -v "$xpath" "$xml_file" 2>/dev/null)
            if [[ -n "$result" ]]; then
                echo "$result"
                return 0
            fi
            ;;
        xmllint)
            local result
            result=$(xmllint --xpath "string($xpath)" "$xml_file" 2>/dev/null)
            if [[ -n "$result" ]]; then
                echo "$result"
                return 0
            fi
            ;;
    esac
    
    echo "$default"
    return 1
}

android_xml_set_attr() {
    local xml_file="$1"
    local xpath="$2"
    local attr="$3"
    local value="$4"
    
    if [[ ! -f "$xml_file" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            xmlstarlet ed -L -u "${xpath}/@${attr}" -v "$value" "$xml_file" 2>/dev/null
            return $?
            ;;
        xmllint)
            local temp_file="${xml_file}.tmp"
            xmllint --shell "$xml_file" <<< "set ${xpath} ${attr} ${value}" > /dev/null 2>&1
            return $?
            ;;
        *)
            local escaped_value="${value//&/&amp;}"
            escaped_value="${escaped_value//</&lt;}"
            escaped_value="${escaped_value//>/&gt;}"
            escaped_value="${escaped_value//\"/&quot;}"
            
            local temp_file="${xml_file}.tmp"
            sed "s|${attr}=\"[^\"]*\"|${attr}=\"${escaped_value}\"|g" "$xml_file" > "$temp_file" 2>/dev/null && \
            mv "$temp_file" "$xml_file"
            return $?
            ;;
    esac
}

android_xml_add_attr() {
    local xml_file="$1"
    local xpath="$2"
    local attr="$3"
    local value="$4"
    
    if [[ ! -f "$xml_file" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            xmlstarlet ed -L -s "$xpath" -t attr -n "$attr" -v "$value" "$xml_file" 2>/dev/null
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

android_xml_add_element() {
    local xml_file="$1"
    local parent_xpath="$2"
    local element_name="$3"
    local element_content="$4"
    
    if [[ ! -f "$xml_file" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            if [[ -n "$element_content" ]]; then
                xmlstarlet ed -L -s "$parent_xpath" -t elem -n "$element_name" -v "$element_content" "$xml_file" 2>/dev/null
            else
                xmlstarlet ed -L -s "$parent_xpath" -t elem -n "$element_name" "$xml_file" 2>/dev/null
            fi
            return $?
            ;;
        *)
            local escaped_content="${element_content//&/&amp;}"
            escaped_content="${escaped_content//</&lt;}"
            escaped_content="${escaped_content//>/&gt;}"
            
            local temp_file="${xml_file}.tmp"
            local element_tag="<${element_name}>${escaped_content}</${element_name}>"
            
            sed "s|</${parent_xpath##*/}>|    ${element_tag}\n</${parent_xpath##*/}>|" "$xml_file" > "$temp_file" 2>/dev/null && \
            mv "$temp_file" "$xml_file"
            return $?
            ;;
    esac
}

android_xml_delete_element() {
    local xml_file="$1"
    local xpath="$2"
    
    if [[ ! -f "$xml_file" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            xmlstarlet ed -L -d "$xpath" "$xml_file" 2>/dev/null
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

android_xml_element_exists() {
    local xml_file="$1"
    local xpath="$2"
    
    if [[ ! -f "$xml_file" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            local count
            count=$(xmlstarlet sel -t -c "$xpath" "$xml_file" 2>/dev/null | wc -c)
            [[ $count -gt 0 ]]
            return $?
            ;;
        xmllint)
            xmllint --xpath "$xpath" "$xml_file" > /dev/null 2>&1
            return $?
            ;;
        *)
            grep -q "<${xpath##*/}" "$xml_file" 2>/dev/null
            return $?
            ;;
    esac
}

android_xml_count_elements() {
    local xml_file="$1"
    local xpath="$2"
    
    if [[ ! -f "$xml_file" ]]; then
        echo "0"
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            local count
            count=$(xmlstarlet sel -t -v "count($xpath)" "$xml_file" 2>/dev/null)
            echo "${count:-0}"
            return 0
            ;;
        xmllint)
            local result
            result=$(xmllint --xpath "$xpath" "$xml_file" 2>/dev/null)
            if [[ -n "$result" ]]; then
                echo "$result" | grep -c "<"
            else
                echo "0"
            fi
            return 0
            ;;
        *)
            echo "0"
            return 1
            ;;
    esac
}

android_xml_validate() {
    local xml_file="$1"
    
    if [[ ! -f "$xml_file" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            xmlstarlet val "$xml_file" 2>/dev/null
            return $?
            ;;
        xmllint)
            xmllint --noout "$xml_file" 2>/dev/null
            return $?
            ;;
        *)
            grep -q "<?xml" "$xml_file" 2>/dev/null
            return $?
            ;;
    esac
}

android_xml_format() {
    local xml_file="$1"
    
    if [[ ! -f "$xml_file" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            xmlstarlet fo "$xml_file" > "${xml_file}.formatted" 2>/dev/null && \
            mv "${xml_file}.formatted" "$xml_file"
            return $?
            ;;
        xmllint)
            xmllint --format "$xml_file" > "${xml_file}.formatted" 2>/dev/null && \
            mv "${xml_file}.formatted" "$xml_file"
            return $?
            ;;
        *)
            return 0
            ;;
    esac
}

android_xml_get_namespaces() {
    local xml_file="$1"
    
    if [[ ! -f "$xml_file" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            xmlstarlet sel -t -m "//*[namespace-uri()!='']" -n -v "namespace-uri()" "$xml_file" 2>/dev/null | sort -u
            return 0
            ;;
        *)
            grep -oP 'xmlns:\K[^=]+="[^"]+"' "$xml_file" 2>/dev/null | sort -u
            return $?
            ;;
    esac
}

android_manifest_read_package() {
    local manifest="$1"
    
    android_xml_read_attr "$manifest" "/manifest" "package" ""
}

android_manifest_read_version_name() {
    local manifest="$1"
    
    android_xml_read_attr "$manifest" "/manifest" "android:versionName" ""
}

android_manifest_read_version_code() {
    local manifest="$1"
    
    android_xml_read_attr "$manifest" "/manifest" "android:versionCode" ""
}

android_manifest_read_min_sdk() {
    local manifest="$1"
    
    android_xml_read_attr "$manifest" "//uses-sdk" "android:minSdkVersion" ""
}

android_manifest_read_target_sdk() {
    local manifest="$1"
    
    android_xml_read_attr "$manifest" "//uses-sdk" "android:targetSdkVersion" ""
}

android_manifest_set_package() {
    local manifest="$1"
    local package="$2"
    
    if [[ ! -f "$manifest" ]]; then
        return 1
    fi
    
    local current_package
    current_package=$(android_manifest_read_package "$manifest")
    
    if [[ -n "$current_package" ]]; then
        android_xml_set_attr "$manifest" "/manifest" "package" "$package"
    else
        case "$ANDROID_XML_TOOL" in
            xmlstarlet)
                xmlstarlet ed -L -i "/manifest" -t attr -n "package" -v "$package" "$manifest" 2>/dev/null
                return $?
                ;;
            *)
                local temp_file="${manifest}.tmp"
                sed "s|<manifest |<manifest package=\"${package}\" |" "$manifest" > "$temp_file" 2>/dev/null && \
                mv "$temp_file" "$manifest"
                return $?
                ;;
        esac
    fi
}

android_manifest_set_version_name() {
    local manifest="$1"
    local version="$2"
    
    android_xml_set_attr "$manifest" "/manifest" "android:versionName" "$version"
}

android_manifest_set_version_code() {
    local manifest="$1"
    local code="$2"
    
    android_xml_set_attr "$manifest" "/manifest" "android:versionCode" "$code"
}

android_manifest_set_min_sdk() {
    local manifest="$1"
    local min_sdk="$2"
    
    if android_xml_element_exists "$manifest" "//uses-sdk"; then
        android_xml_set_attr "$manifest" "//uses-sdk" "android:minSdkVersion" "$min_sdk"
    else
        android_xml_add_element "$manifest" "/manifest" "uses-sdk" ""
        android_xml_add_attr "$manifest" "//uses-sdk" "android:minSdkVersion" "$min_sdk"
    fi
}

android_manifest_set_target_sdk() {
    local manifest="$1"
    local target_sdk="$2"
    
    if android_xml_element_exists "$manifest" "//uses-sdk"; then
        android_xml_set_attr "$manifest" "//uses-sdk" "android:targetSdkVersion" "$target_sdk"
    else
        android_xml_add_element "$manifest" "/manifest" "uses-sdk" ""
        android_xml_add_attr "$manifest" "//uses-sdk" "android:targetSdkVersion" "$target_sdk"
    fi
}

android_manifest_ensure_uses_sdk() {
    local manifest="$1"
    local min_sdk="$2"
    local target_sdk="$3"
    
    if ! android_xml_element_exists "$manifest" "//uses-sdk"; then
        if [[ "$ANDROID_XML_TOOL" == "xmlstarlet" ]]; then
            xmlstarlet ed -L \
                -s "/manifest" -t elem -n "uses-sdk" \
                -i "//uses-sdk[last()]" -t attr -n "android:minSdkVersion" -v "$min_sdk" \
                -i "//uses-sdk[last()]" -t attr -n "android:targetSdkVersion" -v "$target_sdk" \
                "$manifest" 2>/dev/null
            return $?
        else
            local temp_file="${manifest}.tmp"
            local uses_sdk_tag="    <uses-sdk android:minSdkVersion=\"${min_sdk}\" android:targetSdkVersion=\"${target_sdk}\" />"
            
            if grep -q "</application>" "$manifest"; then
                sed "s|</application>|${uses_sdk_tag}\n    </application>|" "$manifest" > "$temp_file"
            else
                sed "s|</manifest>|${uses_sdk_tag}\n</manifest>|" "$manifest" > "$temp_file"
            fi
            mv "$temp_file" "$manifest"
            return 0
        fi
    fi
    
    return 0
}

android_manifest_add_permission() {
    local manifest="$1"
    local permission="$2"
    
    local xpath="//uses-permission[@android:name='${permission}']"
    
    if android_xml_element_exists "$manifest" "$xpath"; then
        return 0
    fi
    
    if [[ "$ANDROID_XML_TOOL" == "xmlstarlet" ]]; then
        xmlstarlet ed -L \
            -s "/manifest" -t elem -n "uses-permission" \
            -i "//uses-permission[last()]" -t attr -n "android:name" -v "$permission" \
            "$manifest" 2>/dev/null
        return $?
    fi
    
    return 1
}

android_manifest_add_uses_permission() {
    local manifest="$1"
    local permission="$2"
    local max_sdk="${3:-}"
    
    local xpath="//uses-permission-sdk-23[@android:name='${permission}']"
    
    if android_xml_element_exists "$manifest" "$xpath"; then
        return 0
    fi
    
    if [[ "$ANDROID_XML_TOOL" == "xmlstarlet" ]]; then
        if [[ -n "$max_sdk" ]]; then
            xmlstarlet ed -L \
                -s "/manifest" -t elem -n "uses-permission-sdk-23" \
                -i "//uses-permission-sdk-23[last()]" -t attr -n "android:name" -v "$permission" \
                -i "//uses-permission-sdk-23[last()]" -t attr -n "android:maxSdkVersion" -v "$max_sdk" \
                "$manifest" 2>/dev/null
        else
            xmlstarlet ed -L \
                -s "/manifest" -t elem -n "uses-permission-sdk-23" \
                -i "//uses-permission-sdk-23[last()]" -t attr -n "android:name" -v "$permission" \
                "$manifest" 2>/dev/null
        fi
        return $?
    fi
    
    return 1
}

android_manifest_add_activity() {
    local manifest="$1"
    local activity_name="$2"
    local is_main="${3:-false}"
    local is_launcher="${4:-false}"
    
    local xpath="//activity[@android:name='${activity_name}']"
    
    if android_xml_element_exists "$manifest" "$xpath"; then
        return 0
    fi
    
    if [[ "$ANDROID_XML_TOOL" == "xmlstarlet" ]]; then
        xmlstarlet ed -L \
            -s "//application" -t elem -n "activity" \
            -i "//activity[last()]" -t attr -n "android:name" -v "$activity_name" \
            "$manifest" 2>/dev/null
        
        if [[ "$is_main" == "true" ]] || [[ "$is_launcher" == "true" ]]; then
            xmlstarlet ed -L \
                -s "//activity[@android:name='${activity_name}']" -t elem -n "intent-filter" \
                -s "//activity[@android:name='${activity_name}']/intent-filter[last()]" -t elem -n "action" \
                -i "//activity[@android:name='${activity_name}']/intent-filter[last()]/action[last()]" -t attr -n "android:name" -v "android.intent.action.MAIN" \
                "$manifest" 2>/dev/null
            
            if [[ "$is_launcher" == "true" ]]; then
                xmlstarlet ed -L \
                    -s "//activity[@android:name='${activity_name}']/intent-filter[last()]" -t elem -n "category" \
                    -i "//activity[@android:name='${activity_name}']/intent-filter[last()]/category[last()]" -t attr -n "android:name" -v "android.intent.category.LAUNCHER" \
                    "$manifest" 2>/dev/null
            fi
        fi
        return 0
    fi
    
    return 1
}

android_manifest_get_activities() {
    local manifest="$1"
    
    if [[ ! -f "$manifest" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            xmlstarlet sel -t -m "//activity" -v "@android:name" -n "$manifest" 2>/dev/null
            return 0
            ;;
        xmllint)
            xmllint --xpath "//activity/@android:name" "$manifest" 2>/dev/null | \
                sed 's/android:name="\([^"]*\)"/\1/g'
            return 0
            ;;
        *)
            grep -oP '<activity[^>]*android:name="\K[^"]+' "$manifest" 2>/dev/null
            return $?
            ;;
    esac
}

android_manifest_get_permissions() {
    local manifest="$1"
    
    if [[ ! -f "$manifest" ]]; then
        return 1
    fi
    
    case "$ANDROID_XML_TOOL" in
        xmlstarlet)
            xmlstarlet sel -t -m "//uses-permission" -v "@android:name" -n "$manifest" 2>/dev/null
            return 0
            ;;
        xmllint)
            xmllint --xpath "//uses-permission/@android:name" "$manifest" 2>/dev/null | \
                sed 's/android:name="\([^"]*\)"/\1/g'
            return 0
            ;;
        *)
            grep -oP '<uses-permission[^>]*android:name="\K[^"]+' "$manifest" 2>/dev/null
            return $?
            ;;
    esac
}

android_manifest_get_application_label() {
    local manifest="$1"
    
    android_xml_read_attr "$manifest" "//application" "android:label" ""
}

android_manifest_set_application_label() {
    local manifest="$1"
    local label="$2"
    
    android_xml_set_attr "$manifest" "//application" "android:label" "$label"
}

android_manifest_get_application_icon() {
    local manifest="$1"
    
    android_xml_read_attr "$manifest" "//application" "android:icon" ""
}

android_manifest_set_application_icon() {
    local manifest="$1"
    local icon="$2"
    
    android_xml_set_attr "$manifest" "//application" "android:icon" "$icon"
}

android_xml_init

fi
