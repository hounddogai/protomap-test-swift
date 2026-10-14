import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set summary is in its life cycle.
    enum OrderSetSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a order set summary and its current status.
    final class OrderSetSummary {
        var code: String
        var label: String
        var attempts: Int
        var segment: String
        var patientRef: String
        var visitMinutes: Int
        var externalRef: String
        var endsAt: Int
        var retries: Int
        var status: OrderSetSummaryStatus

        init(code: String, label: String, attempts: Int, segment: String, patientRef: String, visitMinutes: Int, externalRef: String, endsAt: Int, retries: Int, status: OrderSetSummaryStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.segment = segment
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
            self.externalRef = externalRef
            self.endsAt = endsAt
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == OrderSetSummaryStatus.done || next == OrderSetSummaryStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: OrderSetSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedVolume() -> Double {
            return (Double(visitMinutes) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetSummary {
            return OrderSetSummary(
                code: code,
                label: label,
                attempts: attempts,
                segment: segment,
                patientRef: patientRef,
                visitMinutes: visitMinutes,
                externalRef: externalRef,
                endsAt: endsAt,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a order set summary in status new.
    static func newOrderSetSummary(_ code: String, label: String) -> OrderSetSummary {
        return OrderSetSummary(
            code: code,
            label: label,
            attempts: 0,
            segment: "",
            patientRef: "",
            visitMinutes: 0,
            externalRef: "",
            endsAt: 0,
            retries: 0,
            status: OrderSetSummaryStatus.new
        )
    }
}
