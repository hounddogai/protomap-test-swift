import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted worklist template is in its life cycle.
    enum WeightedWorklistTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted worklist template. Its code is unique within a tenant.
    final class WeightedWorklistTemplate {
        var code: String
        var title: String
        var quantity: Int
        var retries: Int
        var refills: Int
        var country: String
        var approved: Bool
        var updatedAt: Int
        var status: WeightedWorklistTemplateStatus

        init(code: String, title: String, quantity: Int, retries: Int, refills: Int, country: String, approved: Bool, updatedAt: Int, status: WeightedWorklistTemplateStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.retries = retries
            self.refills = refills
            self.country = country
            self.approved = approved
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: WeightedWorklistTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedWorklistTemplateStatus.warming
            case .warming:
                return next == WeightedWorklistTemplateStatus.ready || next == WeightedWorklistTemplateStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == WeightedWorklistTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedWorklistTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted worklist template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netTotal() -> Double {
            return (Double(refills) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedWorklistTemplate {
            return WeightedWorklistTemplate(
                code: code,
                title: title,
                quantity: quantity,
                retries: retries,
                refills: refills,
                country: country,
                approved: approved,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted worklist template in status idle.
    static func newWeightedWorklistTemplate(_ code: String, title: String) -> WeightedWorklistTemplate {
        return WeightedWorklistTemplate(
            code: code,
            title: title,
            quantity: 0,
            retries: 0,
            refills: 0,
            country: "",
            approved: false,
            updatedAt: 0,
            status: WeightedWorklistTemplateStatus.idle
        )
    }
}
