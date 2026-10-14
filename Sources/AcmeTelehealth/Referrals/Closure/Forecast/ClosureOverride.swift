import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure override is in its life cycle.
    enum ClosureOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A closure override. Its code is unique within a tenant.
    final class ClosureOverride {
        var code: String
        var label: String
        var attributes: [String: String]
        var margin: Double
        var diagnosisCode: String
        var status: ClosureOverrideStatus

        init(code: String, label: String, attributes: [String: String], margin: Double, diagnosisCode: String, status: ClosureOverrideStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.margin = margin
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClosureOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ClosureOverrideStatus.approved || next == ClosureOverrideStatus.rejected
            case .approved:
                return next == ClosureOverrideStatus.rejected || next == ClosureOverrideStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ClosureOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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
            return margin
        }

        func copyValue() -> ClosureOverride {
            return ClosureOverride(
                code: code,
                label: label,
                attributes: attributes,
                margin: margin,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a closure override in status proposed.
    static func newClosureOverride(_ code: String, label: String) -> ClosureOverride {
        return ClosureOverride(
            code: code,
            label: label,
            attributes: [:],
            margin: 0.0,
            diagnosisCode: "",
            status: ClosureOverrideStatus.proposed
        )
    }
}
