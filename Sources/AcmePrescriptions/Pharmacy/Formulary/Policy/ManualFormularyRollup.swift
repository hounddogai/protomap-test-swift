import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual formulary rollup is in its life cycle.
    enum ManualFormularyRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One manual formulary rollup, with what the planners need to act on it.
    final class ManualFormularyRollup {
        var code: String
        var name: String
        var discount: Double
        var facility: String
        var batchSize: Int
        var attributes: [String: String]
        var updatedAt: Int
        var retries: Int
        var cost: Double
        var status: ManualFormularyRollupStatus

        init(code: String, name: String, discount: Double, facility: String, batchSize: Int, attributes: [String: String], updatedAt: Int, retries: Int, cost: Double, status: ManualFormularyRollupStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.facility = facility
            self.batchSize = batchSize
            self.attributes = attributes
            self.updatedAt = updatedAt
            self.retries = retries
            self.cost = cost
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

        func canMoveTo(_ next: ManualFormularyRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualFormularyRollupStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualFormularyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual formulary rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func effectiveValue() -> Double {
            return ((discount + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualFormularyRollup {
            return ManualFormularyRollup(
                code: code,
                name: name,
                discount: discount,
                facility: facility,
                batchSize: batchSize,
                attributes: attributes,
                updatedAt: updatedAt,
                retries: retries,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual formulary rollup in status open.
    static func newManualFormularyRollup(_ code: String, name: String) -> ManualFormularyRollup {
        return ManualFormularyRollup(
            code: code,
            name: name,
            discount: 0.0,
            facility: "",
            batchSize: 0,
            attributes: [:],
            updatedAt: 0,
            retries: 0,
            cost: 0.0,
            status: ManualFormularyRollupStatus.`open`
        )
    }
}
