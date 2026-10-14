import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict accession mapping is in its life cycle.
    enum StrictAccessionMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict accession mapping as the accession team keeps it.
    final class StrictAccessionMapping {
        var code: String
        var label: String
        var budget: Double
        var facility: String
        var approved: Bool
        var score: Double
        var version: Int
        var status: StrictAccessionMappingStatus

        init(code: String, label: String, budget: Double, facility: String, approved: Bool, score: Double, version: Int, status: StrictAccessionMappingStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.facility = facility
            self.approved = approved
            self.score = score
            self.version = version
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

        func canMoveTo(_ next: StrictAccessionMappingStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictAccessionMappingStatus.running
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StrictAccessionMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict accession mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedValue() -> Double {
            return ((score + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> StrictAccessionMapping {
            return StrictAccessionMapping(
                code: code,
                label: label,
                budget: budget,
                facility: facility,
                approved: approved,
                score: score,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a strict accession mapping in status new.
    static func newStrictAccessionMapping(_ code: String, label: String) -> StrictAccessionMapping {
        return StrictAccessionMapping(
            code: code,
            label: label,
            budget: 0.0,
            facility: "",
            approved: false,
            score: 0.0,
            version: 0,
            status: StrictAccessionMappingStatus.new
        )
    }
}
