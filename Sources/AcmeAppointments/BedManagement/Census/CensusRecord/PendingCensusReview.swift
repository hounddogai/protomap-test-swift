import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending census review is in its life cycle.
    enum PendingCensusReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a pending census review and its current status.
    final class PendingCensusReview {
        var code: String
        var title: String
        var label: String
        var refills: Int
        var unit: String
        var cost: Double
        var reviewer: String
        var category: String
        var locale: String
        var score: Double
        var channel: String
        var status: PendingCensusReviewStatus

        init(code: String, title: String, label: String, refills: Int, unit: String, cost: Double, reviewer: String, category: String, locale: String, score: Double, channel: String, status: PendingCensusReviewStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.refills = refills
            self.unit = unit
            self.cost = cost
            self.reviewer = reviewer
            self.category = category
            self.locale = locale
            self.score = score
            self.channel = channel
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

        func canMoveTo(_ next: PendingCensusReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingCensusReviewStatus.queued || next == PendingCensusReviewStatus.done
            case .queued:
                return next == PendingCensusReviewStatus.running || next == PendingCensusReviewStatus.failed
            case .running:
                return next == PendingCensusReviewStatus.failed
            case .done:
                return next == PendingCensusReviewStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCensusReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending census review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending census review") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(refills) - score) * 100).rounded() / 100
        }

        func copyValue() -> PendingCensusReview {
            return PendingCensusReview(
                code: code,
                title: title,
                label: label,
                refills: refills,
                unit: unit,
                cost: cost,
                reviewer: reviewer,
                category: category,
                locale: locale,
                score: score,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending census review in status new.
    static func newPendingCensusReview(_ code: String, title: String) -> PendingCensusReview {
        return PendingCensusReview(
            code: code,
            title: title,
            label: "",
            refills: 0,
            unit: "",
            cost: 0.0,
            reviewer: "",
            category: "",
            locale: "",
            score: 0.0,
            channel: "",
            status: PendingCensusReviewStatus.new
        )
    }
}
