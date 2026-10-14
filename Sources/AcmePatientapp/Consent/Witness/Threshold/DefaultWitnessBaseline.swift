import AcmePlatform
import Foundation

extension Consent {
    /// Where a default witness baseline is in its life cycle.
    enum DefaultWitnessBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a default witness baseline and its current status.
    final class DefaultWitnessBaseline {
        var code: String
        var name: String
        var country: String
        var reviewer: String
        var retries: Int
        var updatedAt: Int
        var maximum: Double
        var patientRef: String
        var approved: Bool
        var status: DefaultWitnessBaselineStatus

        init(code: String, name: String, country: String, reviewer: String, retries: Int, updatedAt: Int, maximum: Double, patientRef: String, approved: Bool, status: DefaultWitnessBaselineStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.reviewer = reviewer
            self.retries = retries
            self.updatedAt = updatedAt
            self.maximum = maximum
            self.patientRef = patientRef
            self.approved = approved
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

        func canMoveTo(_ next: DefaultWitnessBaselineStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DefaultWitnessBaselineStatus.failed
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

        func moveTo(_ next: DefaultWitnessBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default witness baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((maximum - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultWitnessBaseline {
            return DefaultWitnessBaseline(
                code: code,
                name: name,
                country: country,
                reviewer: reviewer,
                retries: retries,
                updatedAt: updatedAt,
                maximum: maximum,
                patientRef: patientRef,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default witness baseline in status new.
    static func newDefaultWitnessBaseline(_ code: String, name: String) -> DefaultWitnessBaseline {
        return DefaultWitnessBaseline(
            code: code,
            name: name,
            country: "",
            reviewer: "",
            retries: 0,
            updatedAt: 0,
            maximum: 0.0,
            patientRef: "",
            approved: false,
            status: DefaultWitnessBaselineStatus.new
        )
    }
}
