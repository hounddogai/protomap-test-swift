import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global overtime bundle is in its life cycle.
    enum GlobalOvertimeBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global overtime bundle. Its code is unique within a tenant.
    final class GlobalOvertimeBundle {
        var code: String
        var title: String
        var clinicianID: String
        var refills: Int
        var floorValue: Double
        var endsAt: Int
        var tags: [String]
        var payer: String
        var category: String
        var priority: Int
        var status: GlobalOvertimeBundleStatus

        init(code: String, title: String, clinicianID: String, refills: Int, floorValue: Double, endsAt: Int, tags: [String], payer: String, category: String, priority: Int, status: GlobalOvertimeBundleStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.refills = refills
            self.floorValue = floorValue
            self.endsAt = endsAt
            self.tags = tags
            self.payer = payer
            self.category = category
            self.priority = priority
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

        func canMoveTo(_ next: GlobalOvertimeBundleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalOvertimeBundleStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GlobalOvertimeBundleStatus.reopened
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

        func moveTo(_ next: GlobalOvertimeBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global overtime bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (Double(priority) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> GlobalOvertimeBundle {
            return GlobalOvertimeBundle(
                code: code,
                title: title,
                clinicianID: clinicianID,
                refills: refills,
                floorValue: floorValue,
                endsAt: endsAt,
                tags: tags,
                payer: payer,
                category: category,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global overtime bundle in status open.
    static func newGlobalOvertimeBundle(_ code: String, title: String) -> GlobalOvertimeBundle {
        return GlobalOvertimeBundle(
            code: code,
            title: title,
            clinicianID: "",
            refills: 0,
            floorValue: 0.0,
            endsAt: 0,
            tags: [],
            payer: "",
            category: "",
            priority: 0,
            status: GlobalOvertimeBundleStatus.`open`
        )
    }
}
