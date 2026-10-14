import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol exception is in its life cycle.
    enum CareProtocolExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One care protocol exception, with what the planners need to act on it.
    final class CareProtocolException {
        var code: String
        var title: String
        var description: String
        var active: Bool
        var tags: [String]
        var amount: Double
        var category: String
        var status: CareProtocolExceptionStatus

        init(code: String, title: String, description: String, active: Bool, tags: [String], amount: Double, category: String, status: CareProtocolExceptionStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.active = active
            self.tags = tags
            self.amount = amount
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolExceptionStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CareProtocolExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> CareProtocolException {
            return CareProtocolException(
                code: code,
                title: title,
                description: description,
                active: active,
                tags: tags,
                amount: amount,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a care protocol exception in status created.
    static func newCareProtocolException(_ code: String, title: String) -> CareProtocolException {
        return CareProtocolException(
            code: code,
            title: title,
            description: "",
            active: false,
            tags: [],
            amount: 0.0,
            category: "",
            status: CareProtocolExceptionStatus.created
        )
    }
}
