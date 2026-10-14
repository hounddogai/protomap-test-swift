import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary closure bundle is in its life cycle.
    enum PrimaryClosureBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary closure bundle as the closure team keeps it.
    final class PrimaryClosureBundle {
        var code: String
        var name: String
        var currency: String
        var payer: String
        var allergy: String
        var summary: String
        var facility: String
        var score: Double
        var attributes: [String: String]
        var status: PrimaryClosureBundleStatus

        init(code: String, name: String, currency: String, payer: String, allergy: String, summary: String, facility: String, score: Double, attributes: [String: String], status: PrimaryClosureBundleStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.payer = payer
            self.allergy = allergy
            self.summary = summary
            self.facility = facility
            self.score = score
            self.attributes = attributes
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

        func canMoveTo(_ next: PrimaryClosureBundleStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryClosureBundleStatus.pending
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryClosureBundleStatus.suspended
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

        func moveTo(_ next: PrimaryClosureBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary closure bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PrimaryClosureBundle {
            return PrimaryClosureBundle(
                code: code,
                name: name,
                currency: currency,
                payer: payer,
                allergy: allergy,
                summary: summary,
                facility: facility,
                score: score,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a primary closure bundle in status draft.
    static func newPrimaryClosureBundle(_ code: String, name: String) -> PrimaryClosureBundle {
        return PrimaryClosureBundle(
            code: code,
            name: name,
            currency: "",
            payer: "",
            allergy: "",
            summary: "",
            facility: "",
            score: 0.0,
            attributes: [:],
            status: PrimaryClosureBundleStatus.draft
        )
    }
}
