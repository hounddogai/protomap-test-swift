import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped care protocol draft is in its life cycle.
    enum CappedCareProtocolDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped care protocol draft as the care protocol team keeps it.
    final class CappedCareProtocolDraft {
        var code: String
        var name: String
        var startsAt: Int
        var refills: Int
        var limit: Int
        var budget: Double
        var quantity: Int
        var locale: String
        var status: CappedCareProtocolDraftStatus

        init(code: String, name: String, startsAt: Int, refills: Int, limit: Int, budget: Double, quantity: Int, locale: String, status: CappedCareProtocolDraftStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.refills = refills
            self.limit = limit
            self.budget = budget
            self.quantity = quantity
            self.locale = locale
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

        func canMoveTo(_ next: CappedCareProtocolDraftStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CappedCareProtocolDraftStatus.withdrawn
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

        func moveTo(_ next: CappedCareProtocolDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care protocol draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return ((Double(refills) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCareProtocolDraft {
            return CappedCareProtocolDraft(
                code: code,
                name: name,
                startsAt: startsAt,
                refills: refills,
                limit: limit,
                budget: budget,
                quantity: quantity,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a capped care protocol draft in status proposed.
    static func newCappedCareProtocolDraft(_ code: String, name: String) -> CappedCareProtocolDraft {
        return CappedCareProtocolDraft(
            code: code,
            name: name,
            startsAt: 0,
            refills: 0,
            limit: 0,
            budget: 0.0,
            quantity: 0,
            locale: "",
            status: CappedCareProtocolDraftStatus.proposed
        )
    }
}
