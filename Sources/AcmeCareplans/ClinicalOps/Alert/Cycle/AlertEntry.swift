import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert entry is in its life cycle.
    enum AlertEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A alert entry. Its code is unique within a tenant.
    final class AlertEntry {
        var code: String
        var title: String
        var copay: Double
        var tags: [String]
        var externalRef: String
        var budget: Double
        var acuity: Int
        var payer: String
        var graceDays: Int
        var status: AlertEntryStatus

        init(code: String, title: String, copay: Double, tags: [String], externalRef: String, budget: Double, acuity: Int, payer: String, graceDays: Int, status: AlertEntryStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.tags = tags
            self.externalRef = externalRef
            self.budget = budget
            self.acuity = acuity
            self.payer = payer
            self.graceDays = graceDays
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

        func canMoveTo(_ next: AlertEntryStatus) -> Bool {
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
                case .published, .retired:
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

        func moveTo(_ next: AlertEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return (Double(acuity) * copay * 100).rounded() / 100
        }

        func copyValue() -> AlertEntry {
            return AlertEntry(
                code: code,
                title: title,
                copay: copay,
                tags: tags,
                externalRef: externalRef,
                budget: budget,
                acuity: acuity,
                payer: payer,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert entry in status created.
    static func newAlertEntry(_ code: String, title: String) -> AlertEntry {
        return AlertEntry(
            code: code,
            title: title,
            copay: 0.0,
            tags: [],
            externalRef: "",
            budget: 0.0,
            acuity: 0,
            payer: "",
            graceDays: 0,
            status: AlertEntryStatus.created
        )
    }
}
