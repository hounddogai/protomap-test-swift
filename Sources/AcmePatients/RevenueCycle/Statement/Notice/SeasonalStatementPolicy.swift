import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal statement policy is in its life cycle.
    enum SeasonalStatementPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal statement policy, with what the planners need to act on it.
    final class SeasonalStatementPolicy {
        var code: String
        var name: String
        var procedureCode: String
        var patientRef: String
        var batchSize: Int
        var active: Bool
        var refills: Int
        var archived: Bool
        var segment: String
        var approved: Bool
        var contactEmail: String
        var status: SeasonalStatementPolicyStatus

        init(code: String, name: String, procedureCode: String, patientRef: String, batchSize: Int, active: Bool, refills: Int, archived: Bool, segment: String, approved: Bool, contactEmail: String, status: SeasonalStatementPolicyStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.active = active
            self.refills = refills
            self.archived = archived
            self.segment = segment
            self.approved = approved
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: SeasonalStatementPolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalStatementPolicyStatus.running || next == SeasonalStatementPolicyStatus.done
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

        func moveTo(_ next: SeasonalStatementPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal statement policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return ((Double(batchSize) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalStatementPolicy {
            return SeasonalStatementPolicy(
                code: code,
                name: name,
                procedureCode: procedureCode,
                patientRef: patientRef,
                batchSize: batchSize,
                active: active,
                refills: refills,
                archived: archived,
                segment: segment,
                approved: approved,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal statement policy in status new.
    static func newSeasonalStatementPolicy(_ code: String, name: String) -> SeasonalStatementPolicy {
        return SeasonalStatementPolicy(
            code: code,
            name: name,
            procedureCode: "",
            patientRef: "",
            batchSize: 0,
            active: false,
            refills: 0,
            archived: false,
            segment: "",
            approved: false,
            contactEmail: "",
            status: SeasonalStatementPolicyStatus.new
        )
    }
}
