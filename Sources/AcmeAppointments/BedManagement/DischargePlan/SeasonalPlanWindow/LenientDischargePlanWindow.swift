import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient discharge plan window is in its life cycle.
    enum LenientDischargePlanWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One lenient discharge plan window, with what the planners need to act on it.
    final class LenientDischargePlanWindow {
        var code: String
        var name: String
        var pinned: Bool
        var attributes: [String: String]
        var windowDays: Int
        var label: String
        var diagnosisCode: String
        var visible: Bool
        var threshold: Double
        var country: String
        var status: LenientDischargePlanWindowStatus

        init(code: String, name: String, pinned: Bool, attributes: [String: String], windowDays: Int, label: String, diagnosisCode: String, visible: Bool, threshold: Double, country: String, status: LenientDischargePlanWindowStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.attributes = attributes
            self.windowDays = windowDays
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.visible = visible
            self.threshold = threshold
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientDischargePlanWindowStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LenientDischargePlanWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient discharge plan window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
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

        func netVolume() -> Double {
            return ((Double(windowDays) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> LenientDischargePlanWindow {
            return LenientDischargePlanWindow(
                code: code,
                name: name,
                pinned: pinned,
                attributes: attributes,
                windowDays: windowDays,
                label: label,
                diagnosisCode: diagnosisCode,
                visible: visible,
                threshold: threshold,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a lenient discharge plan window in status created.
    static func newLenientDischargePlanWindow(_ code: String, name: String) -> LenientDischargePlanWindow {
        return LenientDischargePlanWindow(
            code: code,
            name: name,
            pinned: false,
            attributes: [:],
            windowDays: 0,
            label: "",
            diagnosisCode: "",
            visible: false,
            threshold: 0.0,
            country: "",
            status: LenientDischargePlanWindowStatus.created
        )
    }
}
