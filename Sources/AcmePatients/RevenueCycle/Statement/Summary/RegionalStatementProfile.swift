import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional statement profile is in its life cycle.
    enum RegionalStatementProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One regional statement profile, with what the planners need to act on it.
    final class RegionalStatementProfile {
        var code: String
        var title: String
        var quantity: Int
        var visitMinutes: Int
        var externalRef: String
        var copay: Double
        var amount: Double
        var attributes: [String: String]
        var status: RegionalStatementProfileStatus

        init(code: String, title: String, quantity: Int, visitMinutes: Int, externalRef: String, copay: Double, amount: Double, attributes: [String: String], status: RegionalStatementProfileStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.visitMinutes = visitMinutes
            self.externalRef = externalRef
            self.copay = copay
            self.amount = amount
            self.attributes = attributes
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

        func canMoveTo(_ next: RegionalStatementProfileStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RegionalStatementProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalStatementProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional statement profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedTotal() -> Double {
            return ((Double(visitMinutes) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStatementProfile {
            return RegionalStatementProfile(
                code: code,
                title: title,
                quantity: quantity,
                visitMinutes: visitMinutes,
                externalRef: externalRef,
                copay: copay,
                amount: amount,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional statement profile in status created.
    static func newRegionalStatementProfile(_ code: String, title: String) -> RegionalStatementProfile {
        return RegionalStatementProfile(
            code: code,
            title: title,
            quantity: 0,
            visitMinutes: 0,
            externalRef: "",
            copay: 0.0,
            amount: 0.0,
            attributes: [:],
            status: RegionalStatementProfileStatus.created
        )
    }
}
