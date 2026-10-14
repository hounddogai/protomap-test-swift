import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study request is in its life cycle.
    enum StudyRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A study request. Its code is unique within a tenant.
    final class StudyRequest {
        var code: String
        var name: String
        var updatedAt: Int
        var quantity: Int
        var category: String
        var phone: String
        var ownerID: String
        var locale: String
        var dosageMg: Double
        var weight: Double
        var status: StudyRequestStatus

        init(code: String, name: String, updatedAt: Int, quantity: Int, category: String, phone: String, ownerID: String, locale: String, dosageMg: Double, weight: Double, status: StudyRequestStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.quantity = quantity
            self.category = category
            self.phone = phone
            self.ownerID = ownerID
            self.locale = locale
            self.dosageMg = dosageMg
            self.weight = weight
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

        func canMoveTo(_ next: StudyRequestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StudyRequestStatus.resolved || next == StudyRequestStatus.reopened
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StudyRequestStatus.reopened
            case .reopened:
                return next == StudyRequestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedVolume() -> Double {
            return ((Double(updatedAt) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> StudyRequest {
            return StudyRequest(
                code: code,
                name: name,
                updatedAt: updatedAt,
                quantity: quantity,
                category: category,
                phone: phone,
                ownerID: ownerID,
                locale: locale,
                dosageMg: dosageMg,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a study request in status open.
    static func newStudyRequest(_ code: String, name: String) -> StudyRequest {
        return StudyRequest(
            code: code,
            name: name,
            updatedAt: 0,
            quantity: 0,
            category: "",
            phone: "",
            ownerID: "",
            locale: "",
            dosageMg: 0.0,
            weight: 0.0,
            status: StudyRequestStatus.`open`
        )
    }
}
