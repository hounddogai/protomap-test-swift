import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol policy is in its life cycle.
    enum CareProtocolPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a care protocol policy and its current status.
    final class CareProtocolPolicy {
        var code: String
        var name: String
        var locale: String
        var encounterID: String
        var version: Int
        var ownerID: String
        var description: String
        var updatedAt: Int
        var title: String
        var refills: Int
        var quantity: Int
        var status: CareProtocolPolicyStatus

        init(code: String, name: String, locale: String, encounterID: String, version: Int, ownerID: String, description: String, updatedAt: Int, title: String, refills: Int, quantity: Int, status: CareProtocolPolicyStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.encounterID = encounterID
            self.version = version
            self.ownerID = ownerID
            self.description = description
            self.updatedAt = updatedAt
            self.title = title
            self.refills = refills
            self.quantity = quantity
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

        func canMoveTo(_ next: CareProtocolPolicyStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CareProtocolPolicyStatus.suspended
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

        func moveTo(_ next: CareProtocolPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (Double(updatedAt) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolPolicy {
            return CareProtocolPolicy(
                code: code,
                name: name,
                locale: locale,
                encounterID: encounterID,
                version: version,
                ownerID: ownerID,
                description: description,
                updatedAt: updatedAt,
                title: title,
                refills: refills,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a care protocol policy in status draft.
    static func newCareProtocolPolicy(_ code: String, name: String) -> CareProtocolPolicy {
        return CareProtocolPolicy(
            code: code,
            name: name,
            locale: "",
            encounterID: "",
            version: 0,
            ownerID: "",
            description: "",
            updatedAt: 0,
            title: "",
            refills: 0,
            quantity: 0,
            status: CareProtocolPolicyStatus.draft
        )
    }
}
