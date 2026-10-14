import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive transfer entry is in its life cycle.
    enum AdaptiveTransferEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One adaptive transfer entry, with what the planners need to act on it.
    final class AdaptiveTransferEntry {
        var code: String
        var title: String
        var windowDays: Int
        var externalRef: String
        var segment: String
        var allergy: String
        var name: String
        var batchSize: Int
        var amount: Double
        var summary: String
        var retries: Int
        var status: AdaptiveTransferEntryStatus

        init(code: String, title: String, windowDays: Int, externalRef: String, segment: String, allergy: String, name: String, batchSize: Int, amount: Double, summary: String, retries: Int, status: AdaptiveTransferEntryStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.externalRef = externalRef
            self.segment = segment
            self.allergy = allergy
            self.name = name
            self.batchSize = batchSize
            self.amount = amount
            self.summary = summary
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

        func canMoveTo(_ next: AdaptiveTransferEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveTransferEntryStatus.done || next == AdaptiveTransferEntryStatus.failed
            case .queued:
                return next == AdaptiveTransferEntryStatus.running || next == AdaptiveTransferEntryStatus.done
            case .running:
                return next == AdaptiveTransferEntryStatus.done || next == AdaptiveTransferEntryStatus.failed
            case .done:
                return next == AdaptiveTransferEntryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveTransferEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive transfer entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive transfer entry") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((amount - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveTransferEntry {
            return AdaptiveTransferEntry(
                code: code,
                title: title,
                windowDays: windowDays,
                externalRef: externalRef,
                segment: segment,
                allergy: allergy,
                name: name,
                batchSize: batchSize,
                amount: amount,
                summary: summary,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive transfer entry in status new.
    static func newAdaptiveTransferEntry(_ code: String, title: String) -> AdaptiveTransferEntry {
        return AdaptiveTransferEntry(
            code: code,
            title: title,
            windowDays: 0,
            externalRef: "",
            segment: "",
            allergy: "",
            name: "",
            batchSize: 0,
            amount: 0.0,
            summary: "",
            retries: 0,
            status: AdaptiveTransferEntryStatus.new
        )
    }
}
