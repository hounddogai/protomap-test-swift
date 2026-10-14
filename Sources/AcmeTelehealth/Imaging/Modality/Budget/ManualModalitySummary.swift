import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual modality summary is in its life cycle.
    enum ManualModalitySummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual modality summary. Its code is unique within a tenant.
    final class ManualModalitySummary {
        var code: String
        var name: String
        var active: Bool
        var ratio: Double
        var rate: Double
        var facility: String
        var durationMinutes: Int
        var summary: String
        var payer: String
        var status: ManualModalitySummaryStatus

        init(code: String, name: String, active: Bool, ratio: Double, rate: Double, facility: String, durationMinutes: Int, summary: String, payer: String, status: ManualModalitySummaryStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.ratio = ratio
            self.rate = rate
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.summary = summary
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualModalitySummaryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualModalitySummaryStatus.withdrawn
            case .approved:
                return next == ManualModalitySummaryStatus.rejected || next == ManualModalitySummaryStatus.withdrawn
            case .rejected:
                return next == ManualModalitySummaryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualModalitySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual modality summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual modality summary") \(code)"
        }

        func netTotal() -> Double {
            return ((ratio + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualModalitySummary {
            return ManualModalitySummary(
                code: code,
                name: name,
                active: active,
                ratio: ratio,
                rate: rate,
                facility: facility,
                durationMinutes: durationMinutes,
                summary: summary,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual modality summary in status proposed.
    static func newManualModalitySummary(_ code: String, name: String) -> ManualModalitySummary {
        return ManualModalitySummary(
            code: code,
            name: name,
            active: false,
            ratio: 0.0,
            rate: 0.0,
            facility: "",
            durationMinutes: 0,
            summary: "",
            payer: "",
            status: ManualModalitySummaryStatus.proposed
        )
    }
}
