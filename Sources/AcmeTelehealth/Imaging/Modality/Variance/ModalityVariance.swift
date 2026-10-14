import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality variance is in its life cycle.
    enum ModalityVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A modality variance. Its code is unique within a tenant.
    final class ModalityVariance {
        var code: String
        var label: String
        var capacity: Int
        var patientRef: String
        var graceDays: Int
        var refills: Int
        var createdAt: Int
        var status: ModalityVarianceStatus

        init(code: String, label: String, capacity: Int, patientRef: String, graceDays: Int, refills: Int, createdAt: Int, status: ModalityVarianceStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.patientRef = patientRef
            self.graceDays = graceDays
            self.refills = refills
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ModalityVarianceStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ModalityVarianceStatus.reopened || next == ModalityVarianceStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ModalityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedVolume() -> Double {
            return ((Double(capacity) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityVariance {
            return ModalityVariance(
                code: code,
                label: label,
                capacity: capacity,
                patientRef: patientRef,
                graceDays: graceDays,
                refills: refills,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a modality variance in status open.
    static func newModalityVariance(_ code: String, label: String) -> ModalityVariance {
        return ModalityVariance(
            code: code,
            label: label,
            capacity: 0,
            patientRef: "",
            graceDays: 0,
            refills: 0,
            createdAt: 0,
            status: ModalityVarianceStatus.`open`
        )
    }
}
