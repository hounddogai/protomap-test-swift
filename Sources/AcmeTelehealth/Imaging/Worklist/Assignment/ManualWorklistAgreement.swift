import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual worklist agreement is in its life cycle.
    enum ManualWorklistAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One manual worklist agreement, with what the planners need to act on it.
    final class ManualWorklistAgreement {
        var code: String
        var title: String
        var durationMinutes: Int
        var weight: Double
        var category: String
        var ratio: Double
        var createdAt: Int
        var status: ManualWorklistAgreementStatus

        init(code: String, title: String, durationMinutes: Int, weight: Double, category: String, ratio: Double, createdAt: Int, status: ManualWorklistAgreementStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.category = category
            self.ratio = ratio
            self.createdAt = createdAt
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

        func canMoveTo(_ next: ManualWorklistAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualWorklistAgreementStatus.approved || next == ManualWorklistAgreementStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualWorklistAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual worklist agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return (ratio * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> ManualWorklistAgreement {
            return ManualWorklistAgreement(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                weight: weight,
                category: category,
                ratio: ratio,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual worklist agreement in status proposed.
    static func newManualWorklistAgreement(_ code: String, title: String) -> ManualWorklistAgreement {
        return ManualWorklistAgreement(
            code: code,
            title: title,
            durationMinutes: 0,
            weight: 0.0,
            category: "",
            ratio: 0.0,
            createdAt: 0,
            status: ManualWorklistAgreementStatus.proposed
        )
    }
}
