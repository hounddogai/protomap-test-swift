import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual witness threshold is in its life cycle.
    enum ManualWitnessThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual witness threshold. Its code is unique within a tenant.
    final class ManualWitnessThreshold {
        var code: String
        var name: String
        var phone: String
        var locale: String
        var contactEmail: String
        var externalRef: String
        var startsAt: Int
        var summary: String
        var discount: Double
        var sequence: Int
        var budget: Double
        var status: ManualWitnessThresholdStatus

        init(code: String, name: String, phone: String, locale: String, contactEmail: String, externalRef: String, startsAt: Int, summary: String, discount: Double, sequence: Int, budget: Double, status: ManualWitnessThresholdStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.locale = locale
            self.contactEmail = contactEmail
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.summary = summary
            self.discount = discount
            self.sequence = sequence
            self.budget = budget
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

        func canMoveTo(_ next: ManualWitnessThresholdStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualWitnessThresholdStatus.pending
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ManualWitnessThresholdStatus.closed
            case .suspended:
                return next == ManualWitnessThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualWitnessThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual witness threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedVolume() -> Double {
            return ((Double(sequence) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualWitnessThreshold {
            return ManualWitnessThreshold(
                code: code,
                name: name,
                phone: phone,
                locale: locale,
                contactEmail: contactEmail,
                externalRef: externalRef,
                startsAt: startsAt,
                summary: summary,
                discount: discount,
                sequence: sequence,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual witness threshold in status draft.
    static func newManualWitnessThreshold(_ code: String, name: String) -> ManualWitnessThreshold {
        return ManualWitnessThreshold(
            code: code,
            name: name,
            phone: "",
            locale: "",
            contactEmail: "",
            externalRef: "",
            startsAt: 0,
            summary: "",
            discount: 0.0,
            sequence: 0,
            budget: 0.0,
            status: ManualWitnessThresholdStatus.draft
        )
    }
}
