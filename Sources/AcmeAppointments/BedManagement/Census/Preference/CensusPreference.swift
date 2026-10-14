import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census preference is in its life cycle.
    enum CensusPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A census preference as the census team keeps it.
    final class CensusPreference {
        var code: String
        var title: String
        var procedureCode: String
        var tags: [String]
        var visible: Bool
        var archived: Bool
        var timezone: String
        var floorValue: Double
        var label: String
        var ward: String
        var attributes: [String: String]
        var status: CensusPreferenceStatus

        init(code: String, title: String, procedureCode: String, tags: [String], visible: Bool, archived: Bool, timezone: String, floorValue: Double, label: String, ward: String, attributes: [String: String], status: CensusPreferenceStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.tags = tags
            self.visible = visible
            self.archived = archived
            self.timezone = timezone
            self.floorValue = floorValue
            self.label = label
            self.ward = ward
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == CensusPreferenceStatus.warming || next == CensusPreferenceStatus.stopped
            case .warming:
                return next == CensusPreferenceStatus.ready || next == CensusPreferenceStatus.stopped
            case .ready:
                return next == CensusPreferenceStatus.stopped
            case .draining:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> CensusPreference {
            return CensusPreference(
                code: code,
                title: title,
                procedureCode: procedureCode,
                tags: tags,
                visible: visible,
                archived: archived,
                timezone: timezone,
                floorValue: floorValue,
                label: label,
                ward: ward,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a census preference in status idle.
    static func newCensusPreference(_ code: String, title: String) -> CensusPreference {
        return CensusPreference(
            code: code,
            title: title,
            procedureCode: "",
            tags: [],
            visible: false,
            archived: false,
            timezone: "",
            floorValue: 0.0,
            label: "",
            ward: "",
            attributes: [:],
            status: CensusPreferenceStatus.idle
        )
    }
}
