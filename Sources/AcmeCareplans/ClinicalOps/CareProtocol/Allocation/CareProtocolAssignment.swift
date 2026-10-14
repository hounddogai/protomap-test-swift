import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol assignment is in its life cycle.
    enum CareProtocolAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One care protocol assignment, with what the planners need to act on it.
    final class CareProtocolAssignment {
        var code: String
        var label: String
        var score: Double
        var region: String
        var createdAt: Int
        var tags: [String]
        var country: String
        var retries: Int
        var copay: Double
        var allergy: String
        var status: CareProtocolAssignmentStatus

        init(code: String, label: String, score: Double, region: String, createdAt: Int, tags: [String], country: String, retries: Int, copay: Double, allergy: String, status: CareProtocolAssignmentStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.region = region
            self.createdAt = createdAt
            self.tags = tags
            self.country = country
            self.retries = retries
            self.copay = copay
            self.allergy = allergy
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

        func canMoveTo(_ next: CareProtocolAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolAssignmentStatus.queued || next == CareProtocolAssignmentStatus.running
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
                case .failed:
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

        func moveTo(_ next: CareProtocolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((score - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAssignment {
            return CareProtocolAssignment(
                code: code,
                label: label,
                score: score,
                region: region,
                createdAt: createdAt,
                tags: tags,
                country: country,
                retries: retries,
                copay: copay,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care protocol assignment in status new.
    static func newCareProtocolAssignment(_ code: String, label: String) -> CareProtocolAssignment {
        return CareProtocolAssignment(
            code: code,
            label: label,
            score: 0.0,
            region: "",
            createdAt: 0,
            tags: [],
            country: "",
            retries: 0,
            copay: 0.0,
            allergy: "",
            status: CareProtocolAssignmentStatus.new
        )
    }
}
