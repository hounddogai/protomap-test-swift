import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read rule is in its life cycle.
    enum ReadRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a read rule and its current status.
    final class ReadRule {
        var code: String
        var name: String
        var locale: String
        var diagnosisCode: String
        var batchSize: Int
        var visitMinutes: Int
        var status: ReadRuleStatus

        init(code: String, name: String, locale: String, diagnosisCode: String, batchSize: Int, visitMinutes: Int, status: ReadRuleStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.diagnosisCode = diagnosisCode
            self.batchSize = batchSize
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ReadRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == ReadRuleStatus.queued || next == ReadRuleStatus.running
            case .queued:
                return next == ReadRuleStatus.failed
            case .running:
                return next == ReadRuleStatus.done
            case .done:
                return next == ReadRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("read rule") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(batchSize) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ReadRule {
            return ReadRule(
                code: code,
                name: name,
                locale: locale,
                diagnosisCode: diagnosisCode,
                batchSize: batchSize,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a read rule in status new.
    static func newReadRule(_ code: String, name: String) -> ReadRule {
        return ReadRule(
            code: code,
            name: name,
            locale: "",
            diagnosisCode: "",
            batchSize: 0,
            visitMinutes: 0,
            status: ReadRuleStatus.new
        )
    }
}
