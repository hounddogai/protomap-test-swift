import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive claim rollup is in its life cycle.
    enum AdaptiveClaimRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A adaptive claim rollup. Its code is unique within a tenant.
    final class AdaptiveClaimRollup {
        var code: String
        var name: String
        var locale: String
        var externalRef: String
        var score: Double
        var clinicianID: String
        var title: String
        var approved: Bool
        var ceiling: Double
        var sequence: Int
        var procedureCode: String
        var status: AdaptiveClaimRollupStatus

        init(code: String, name: String, locale: String, externalRef: String, score: Double, clinicianID: String, title: String, approved: Bool, ceiling: Double, sequence: Int, procedureCode: String, status: AdaptiveClaimRollupStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.externalRef = externalRef
            self.score = score
            self.clinicianID = clinicianID
            self.title = title
            self.approved = approved
            self.ceiling = ceiling
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveClaimRollupStatus) -> Bool {
            switch status {
            case .planned:
                return next == AdaptiveClaimRollupStatus.scheduled || next == AdaptiveClaimRollupStatus.inProgress
            case .scheduled:
                return next == AdaptiveClaimRollupStatus.cancelled
            case .inProgress:
                return next == AdaptiveClaimRollupStatus.completed || next == AdaptiveClaimRollupStatus.cancelled
            case .completed:
                return next == AdaptiveClaimRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveClaimRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive claim rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive claim rollup") \(code)"
        }

        func weightedValue() -> Double {
            return ((ceiling - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveClaimRollup {
            return AdaptiveClaimRollup(
                code: code,
                name: name,
                locale: locale,
                externalRef: externalRef,
                score: score,
                clinicianID: clinicianID,
                title: title,
                approved: approved,
                ceiling: ceiling,
                sequence: sequence,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive claim rollup in status planned.
    static func newAdaptiveClaimRollup(_ code: String, name: String) -> AdaptiveClaimRollup {
        return AdaptiveClaimRollup(
            code: code,
            name: name,
            locale: "",
            externalRef: "",
            score: 0.0,
            clinicianID: "",
            title: "",
            approved: false,
            ceiling: 0.0,
            sequence: 0,
            procedureCode: "",
            status: AdaptiveClaimRollupStatus.planned
        )
    }
}
