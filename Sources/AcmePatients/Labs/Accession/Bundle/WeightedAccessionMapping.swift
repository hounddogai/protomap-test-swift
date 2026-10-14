import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted accession mapping is in its life cycle.
    enum WeightedAccessionMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a weighted accession mapping and its current status.
    final class WeightedAccessionMapping {
        var code: String
        var title: String
        var refills: Int
        var region: String
        var country: String
        var encounterID: String
        var visitMinutes: Int
        var priority: Int
        var status: WeightedAccessionMappingStatus

        init(code: String, title: String, refills: Int, region: String, country: String, encounterID: String, visitMinutes: Int, priority: Int, status: WeightedAccessionMappingStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.region = region
            self.country = country
            self.encounterID = encounterID
            self.visitMinutes = visitMinutes
            self.priority = priority
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

        func canMoveTo(_ next: WeightedAccessionMappingStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WeightedAccessionMappingStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedAccessionMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted accession mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((Double(refills) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAccessionMapping {
            return WeightedAccessionMapping(
                code: code,
                title: title,
                refills: refills,
                region: region,
                country: country,
                encounterID: encounterID,
                visitMinutes: visitMinutes,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted accession mapping in status created.
    static func newWeightedAccessionMapping(_ code: String, title: String) -> WeightedAccessionMapping {
        return WeightedAccessionMapping(
            code: code,
            title: title,
            refills: 0,
            region: "",
            country: "",
            encounterID: "",
            visitMinutes: 0,
            priority: 0,
            status: WeightedAccessionMappingStatus.created
        )
    }
}
