import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense request is in its life cycle.
    enum DispenseRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A dispense request as the dispense team keeps it.
    final class DispenseRequest {
        var code: String
        var name: String
        var phone: String
        var weight: Double
        var tags: [String]
        var status: DispenseRequestStatus

        init(code: String, name: String, phone: String, weight: Double, tags: [String], status: DispenseRequestStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.weight = weight
            self.tags = tags
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

        func canMoveTo(_ next: DispenseRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == DispenseRequestStatus.pending
            case .pending:
                return next == DispenseRequestStatus.closed
            case .active:
                return next == DispenseRequestStatus.suspended || next == DispenseRequestStatus.closed
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

        func moveTo(_ next: DispenseRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
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
            return weight
        }

        func copyValue() -> DispenseRequest {
            return DispenseRequest(code: code, name: name, phone: phone, weight: weight, tags: tags, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a dispense request in status draft.
    static func newDispenseRequest(_ code: String, name: String) -> DispenseRequest {
        return DispenseRequest(
            code: code,
            name: name,
            phone: "",
            weight: 0.0,
            tags: [],
            status: DispenseRequestStatus.draft
        )
    }
}
