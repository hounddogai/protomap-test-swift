import AcmePlatform
import Foundation

extension Labs {
    /// Where a result milestone is in its life cycle.
    enum ResultMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A result milestone as the result team keeps it.
    final class ResultMilestone {
        var code: String
        var name: String
        var batchSize: Int
        var version: Int
        var payer: String
        var externalRef: String
        var currency: String
        var diagnosisCode: String
        var category: String
        var threshold: Double
        var source: String
        var status: ResultMilestoneStatus

        init(code: String, name: String, batchSize: Int, version: Int, payer: String, externalRef: String, currency: String, diagnosisCode: String, category: String, threshold: Double, source: String, status: ResultMilestoneStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.version = version
            self.payer = payer
            self.externalRef = externalRef
            self.currency = currency
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.threshold = threshold
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == ResultMilestoneStatus.stopped
            case .warming:
                return next == ResultMilestoneStatus.ready || next == ResultMilestoneStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ResultMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return ((threshold + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ResultMilestone {
            return ResultMilestone(
                code: code,
                name: name,
                batchSize: batchSize,
                version: version,
                payer: payer,
                externalRef: externalRef,
                currency: currency,
                diagnosisCode: diagnosisCode,
                category: category,
                threshold: threshold,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a result milestone in status idle.
    static func newResultMilestone(_ code: String, name: String) -> ResultMilestone {
        return ResultMilestone(
            code: code,
            name: name,
            batchSize: 0,
            version: 0,
            payer: "",
            externalRef: "",
            currency: "",
            diagnosisCode: "",
            category: "",
            threshold: 0.0,
            source: "",
            status: ResultMilestoneStatus.idle
        )
    }
}
