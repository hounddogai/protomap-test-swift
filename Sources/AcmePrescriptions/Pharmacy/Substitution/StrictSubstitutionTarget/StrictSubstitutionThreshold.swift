import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict substitution threshold is in its life cycle.
    enum StrictSubstitutionThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict substitution threshold. Its code is unique within a tenant.
    final class StrictSubstitutionThreshold {
        var code: String
        var label: String
        var attributes: [String: String]
        var discount: Double
        var approved: Bool
        var status: StrictSubstitutionThresholdStatus

        init(code: String, label: String, attributes: [String: String], discount: Double, approved: Bool, status: StrictSubstitutionThresholdStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.discount = discount
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictSubstitutionThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictSubstitutionThresholdStatus.running || next == StrictSubstitutionThresholdStatus.done
            case .queued:
                return next == StrictSubstitutionThresholdStatus.running || next == StrictSubstitutionThresholdStatus.done
            case .running:
                return next == StrictSubstitutionThresholdStatus.failed
            case .done:
                return next == StrictSubstitutionThresholdStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSubstitutionThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict substitution threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict substitution threshold") \(code)"
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
            return discount
        }

        func copyValue() -> StrictSubstitutionThreshold {
            return StrictSubstitutionThreshold(
                code: code,
                label: label,
                attributes: attributes,
                discount: discount,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict substitution threshold in status new.
    static func newStrictSubstitutionThreshold(_ code: String, label: String) -> StrictSubstitutionThreshold {
        return StrictSubstitutionThreshold(
            code: code,
            label: label,
            attributes: [:],
            discount: 0.0,
            approved: false,
            status: StrictSubstitutionThresholdStatus.new
        )
    }
}
