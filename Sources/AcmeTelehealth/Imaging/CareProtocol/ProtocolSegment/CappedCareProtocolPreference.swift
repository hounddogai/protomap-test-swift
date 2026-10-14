import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped care protocol preference is in its life cycle.
    enum CappedCareProtocolPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One capped care protocol preference, with what the planners need to act on it.
    final class CappedCareProtocolPreference {
        var code: String
        var title: String
        var source: String
        var archived: Bool
        var clinicianID: String
        var quantity: Int
        var status: CappedCareProtocolPreferenceStatus

        init(code: String, title: String, source: String, archived: Bool, clinicianID: String, quantity: Int, status: CappedCareProtocolPreferenceStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.archived = archived
            self.clinicianID = clinicianID
            self.quantity = quantity
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

        func canMoveTo(_ next: CappedCareProtocolPreferenceStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedCareProtocolPreferenceStatus.published
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: CappedCareProtocolPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care protocol preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CappedCareProtocolPreference {
            return CappedCareProtocolPreference(
                code: code,
                title: title,
                source: source,
                archived: archived,
                clinicianID: clinicianID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped care protocol preference in status created.
    static func newCappedCareProtocolPreference(_ code: String, title: String) -> CappedCareProtocolPreference {
        return CappedCareProtocolPreference(
            code: code,
            title: title,
            source: "",
            archived: false,
            clinicianID: "",
            quantity: 0,
            status: CappedCareProtocolPreferenceStatus.created
        )
    }
}
