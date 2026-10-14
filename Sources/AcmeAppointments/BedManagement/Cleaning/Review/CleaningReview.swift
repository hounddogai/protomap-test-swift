import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning review is in its life cycle.
    enum CleaningReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A cleaning review. Its code is unique within a tenant.
    final class CleaningReview {
        var code: String
        var name: String
        var phone: String
        var budget: Double
        var acuity: Int
        var minimum: Double
        var ward: String
        var visible: Bool
        var status: CleaningReviewStatus

        init(code: String, name: String, phone: String, budget: Double, acuity: Int, minimum: Double, ward: String, visible: Bool, status: CleaningReviewStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.budget = budget
            self.acuity = acuity
            self.minimum = minimum
            self.ward = ward
            self.visible = visible
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

        func canMoveTo(_ next: CleaningReviewStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CleaningReviewStatus.stopped
            case .ready:
                return next == CleaningReviewStatus.draining || next == CleaningReviewStatus.stopped
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

        func moveTo(_ next: CleaningReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netTotal() -> Double {
            return ((Double(acuity) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> CleaningReview {
            return CleaningReview(
                code: code,
                name: name,
                phone: phone,
                budget: budget,
                acuity: acuity,
                minimum: minimum,
                ward: ward,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a cleaning review in status idle.
    static func newCleaningReview(_ code: String, name: String) -> CleaningReview {
        return CleaningReview(
            code: code,
            name: name,
            phone: "",
            budget: 0.0,
            acuity: 0,
            minimum: 0.0,
            ward: "",
            visible: false,
            status: CleaningReviewStatus.idle
        )
    }
}
