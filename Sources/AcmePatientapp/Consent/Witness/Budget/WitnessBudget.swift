import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness budget is in its life cycle.
    enum WitnessBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a witness budget and its current status.
    final class WitnessBudget {
        var code: String
        var name: String
        var allergy: String
        var createdAt: Int
        var externalRef: String
        var notes: String
        var ratio: Double
        var refills: Int
        var region: String
        var status: WitnessBudgetStatus

        init(code: String, name: String, allergy: String, createdAt: Int, externalRef: String, notes: String, ratio: Double, refills: Int, region: String, status: WitnessBudgetStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.notes = notes
            self.ratio = ratio
            self.refills = refills
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessBudgetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WitnessBudgetStatus.expired
            case .revoked:
                return next == WitnessBudgetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return (Double(refills) * ratio * 100).rounded() / 100
        }

        func copyValue() -> WitnessBudget {
            return WitnessBudget(
                code: code,
                name: name,
                allergy: allergy,
                createdAt: createdAt,
                externalRef: externalRef,
                notes: notes,
                ratio: ratio,
                refills: refills,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a witness budget in status requested.
    static func newWitnessBudget(_ code: String, name: String) -> WitnessBudget {
        return WitnessBudget(
            code: code,
            name: name,
            allergy: "",
            createdAt: 0,
            externalRef: "",
            notes: "",
            ratio: 0.0,
            refills: 0,
            region: "",
            status: WitnessBudgetStatus.requested
        )
    }
}
