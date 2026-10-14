import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional alert notice is in its life cycle.
    enum RegionalAlertNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional alert notice. Its code is unique within a tenant.
    final class RegionalAlertNotice {
        var code: String
        var label: String
        var summary: String
        var sequence: Int
        var locale: String
        var rate: Double
        var payer: String
        var pinned: Bool
        var status: RegionalAlertNoticeStatus

        init(code: String, label: String, summary: String, sequence: Int, locale: String, rate: Double, payer: String, pinned: Bool, status: RegionalAlertNoticeStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.sequence = sequence
            self.locale = locale
            self.rate = rate
            self.payer = payer
            self.pinned = pinned
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

        func canMoveTo(_ next: RegionalAlertNoticeStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalAlertNoticeStatus.published || next == RegionalAlertNoticeStatus.retired
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

        func moveTo(_ next: RegionalAlertNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional alert notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional alert notice") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(sequence) - rate) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAlertNotice {
            return RegionalAlertNotice(
                code: code,
                label: label,
                summary: summary,
                sequence: sequence,
                locale: locale,
                rate: rate,
                payer: payer,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional alert notice in status created.
    static func newRegionalAlertNotice(_ code: String, label: String) -> RegionalAlertNotice {
        return RegionalAlertNotice(
            code: code,
            label: label,
            summary: "",
            sequence: 0,
            locale: "",
            rate: 0.0,
            payer: "",
            pinned: false,
            status: RegionalAlertNoticeStatus.created
        )
    }
}
