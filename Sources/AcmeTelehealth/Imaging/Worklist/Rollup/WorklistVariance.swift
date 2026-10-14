import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist variance is in its life cycle.
    enum WorklistVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A worklist variance. Its code is unique within a tenant.
    final class WorklistVariance {
        var code: String
        var label: String
        var patientRef: String
        var ratio: Double
        var attributes: [String: String]
        var status: WorklistVarianceStatus

        init(code: String, label: String, patientRef: String, ratio: Double, attributes: [String: String], status: WorklistVarianceStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.ratio = ratio
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistVarianceStatus) -> Bool {
            switch status {
            case .draft:
                return next == WorklistVarianceStatus.pending
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: WorklistVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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
            return ratio
        }

        func copyValue() -> WorklistVariance {
            return WorklistVariance(
                code: code,
                label: label,
                patientRef: patientRef,
                ratio: ratio,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a worklist variance in status draft.
    static func newWorklistVariance(_ code: String, label: String) -> WorklistVariance {
        return WorklistVariance(
            code: code,
            label: label,
            patientRef: "",
            ratio: 0.0,
            attributes: [:],
            status: WorklistVarianceStatus.draft
        )
    }
}
