import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form threshold is in its life cycle.
    enum ConsentFormThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a consent form threshold and its current status.
    final class ConsentFormThreshold {
        var code: String
        var title: String
        var attributes: [String: String]
        var allergy: String
        var notes: String
        var floorValue: Double
        var label: String
        var tags: [String]
        var patientRef: String
        var status: ConsentFormThresholdStatus

        init(code: String, title: String, attributes: [String: String], allergy: String, notes: String, floorValue: Double, label: String, tags: [String], patientRef: String, status: ConsentFormThresholdStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.allergy = allergy
            self.notes = notes
            self.floorValue = floorValue
            self.label = label
            self.tags = tags
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == ConsentFormThresholdStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ConsentFormThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("consent form threshold") \(code)"
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

        func copyValue() -> ConsentFormThreshold {
            return ConsentFormThreshold(
                code: code,
                title: title,
                attributes: attributes,
                allergy: allergy,
                notes: notes,
                floorValue: floorValue,
                label: label,
                tags: tags,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a consent form threshold in status requested.
    static func newConsentFormThreshold(_ code: String, title: String) -> ConsentFormThreshold {
        return ConsentFormThreshold(
            code: code,
            title: title,
            attributes: [:],
            allergy: "",
            notes: "",
            floorValue: 0.0,
            label: "",
            tags: [],
            patientRef: "",
            status: ConsentFormThresholdStatus.requested
        )
    }
}
