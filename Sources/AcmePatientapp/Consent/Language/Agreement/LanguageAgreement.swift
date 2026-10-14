import AcmePlatform
import Foundation

extension Consent {
    /// Where a language agreement is in its life cycle.
    enum LanguageAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One language agreement, with what the planners need to act on it.
    final class LanguageAgreement {
        var code: String
        var label: String
        var tags: [String]
        var name: String
        var region: String
        var quantity: Int
        var amount: Double
        var windowDays: Int
        var status: LanguageAgreementStatus

        init(code: String, label: String, tags: [String], name: String, region: String, quantity: Int, amount: Double, windowDays: Int, status: LanguageAgreementStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.name = name
            self.region = region
            self.quantity = quantity
            self.amount = amount
            self.windowDays = windowDays
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

        func canMoveTo(_ next: LanguageAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == LanguageAgreementStatus.active
            case .pending:
                return next == LanguageAgreementStatus.active || next == LanguageAgreementStatus.suspended
            case .active:
                return next == LanguageAgreementStatus.suspended || next == LanguageAgreementStatus.closed
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

        func moveTo(_ next: LanguageAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("language agreement") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((Double(quantity) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageAgreement {
            return LanguageAgreement(
                code: code,
                label: label,
                tags: tags,
                name: name,
                region: region,
                quantity: quantity,
                amount: amount,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a language agreement in status draft.
    static func newLanguageAgreement(_ code: String, label: String) -> LanguageAgreement {
        return LanguageAgreement(
            code: code,
            label: label,
            tags: [],
            name: "",
            region: "",
            quantity: 0,
            amount: 0.0,
            windowDays: 0,
            status: LanguageAgreementStatus.draft
        )
    }
}
