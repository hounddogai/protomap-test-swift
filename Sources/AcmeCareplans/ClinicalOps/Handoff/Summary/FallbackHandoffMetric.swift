import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback handoff metric is in its life cycle.
    enum FallbackHandoffMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a fallback handoff metric and its current status.
    final class FallbackHandoffMetric {
        var code: String
        var title: String
        var externalRef: String
        var phone: String
        var tags: [String]
        var dosageMg: Double
        var encounterID: String
        var archived: Bool
        var refills: Int
        var approved: Bool
        var batchSize: Int
        var status: FallbackHandoffMetricStatus

        init(code: String, title: String, externalRef: String, phone: String, tags: [String], dosageMg: Double, encounterID: String, archived: Bool, refills: Int, approved: Bool, batchSize: Int, status: FallbackHandoffMetricStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.phone = phone
            self.tags = tags
            self.dosageMg = dosageMg
            self.encounterID = encounterID
            self.archived = archived
            self.refills = refills
            self.approved = approved
            self.batchSize = batchSize
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

        func canMoveTo(_ next: FallbackHandoffMetricStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackHandoffMetricStatus.queued
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FallbackHandoffMetricStatus.done
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

        func moveTo(_ next: FallbackHandoffMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback handoff metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func netExposure() -> Double {
            return ((Double(refills) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> FallbackHandoffMetric {
            return FallbackHandoffMetric(
                code: code,
                title: title,
                externalRef: externalRef,
                phone: phone,
                tags: tags,
                dosageMg: dosageMg,
                encounterID: encounterID,
                archived: archived,
                refills: refills,
                approved: approved,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback handoff metric in status new.
    static func newFallbackHandoffMetric(_ code: String, title: String) -> FallbackHandoffMetric {
        return FallbackHandoffMetric(
            code: code,
            title: title,
            externalRef: "",
            phone: "",
            tags: [],
            dosageMg: 0.0,
            encounterID: "",
            archived: false,
            refills: 0,
            approved: false,
            batchSize: 0,
            status: FallbackHandoffMetricStatus.new
        )
    }
}
