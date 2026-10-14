import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling assessment mapping is in its life cycle.
    enum RollingAssessmentMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling assessment mapping as the assessment team keeps it.
    final class RollingAssessmentMapping {
        var code: String
        var name: String
        var score: Double
        var copay: Double
        var floorValue: Double
        var region: String
        var title: String
        var batchSize: Int
        var tags: [String]
        var status: RollingAssessmentMappingStatus

        init(code: String, name: String, score: Double, copay: Double, floorValue: Double, region: String, title: String, batchSize: Int, tags: [String], status: RollingAssessmentMappingStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.copay = copay
            self.floorValue = floorValue
            self.region = region
            self.title = title
            self.batchSize = batchSize
            self.tags = tags
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

        func canMoveTo(_ next: RollingAssessmentMappingStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingAssessmentMappingStatus.queued || next == RollingAssessmentMappingStatus.running
            case .queued:
                return next == RollingAssessmentMappingStatus.failed
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

        func moveTo(_ next: RollingAssessmentMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling assessment mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling assessment mapping") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return (Double(batchSize) * copay * 100).rounded() / 100
        }

        func copyValue() -> RollingAssessmentMapping {
            return RollingAssessmentMapping(
                code: code,
                name: name,
                score: score,
                copay: copay,
                floorValue: floorValue,
                region: region,
                title: title,
                batchSize: batchSize,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling assessment mapping in status new.
    static func newRollingAssessmentMapping(_ code: String, name: String) -> RollingAssessmentMapping {
        return RollingAssessmentMapping(
            code: code,
            name: name,
            score: 0.0,
            copay: 0.0,
            floorValue: 0.0,
            region: "",
            title: "",
            batchSize: 0,
            tags: [],
            status: RollingAssessmentMappingStatus.new
        )
    }
}
