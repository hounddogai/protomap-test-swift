import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement profile is in its life cycle.
    enum StatementProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a statement profile and its current status.
    final class StatementProfile {
        var code: String
        var name: String
        var description: String
        var budget: Double
        var windowDays: Int
        var status: StatementProfileStatus

        init(code: String, name: String, description: String, budget: Double, windowDays: Int, status: StatementProfileStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.budget = budget
            self.windowDays = windowDays
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

        func canMoveTo(_ next: StatementProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == StatementProfileStatus.queued
            case .queued:
                return next == StatementProfileStatus.running || next == StatementProfileStatus.done
            case .running:
                return next == StatementProfileStatus.failed
            case .done:
                return next == StatementProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("statement profile") \(code)"
        }

        func weightedExposure() -> Double {
            return (budget * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> StatementProfile {
            return StatementProfile(
                code: code,
                name: name,
                description: description,
                budget: budget,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a statement profile in status new.
    static func newStatementProfile(_ code: String, name: String) -> StatementProfile {
        return StatementProfile(
            code: code,
            name: name,
            description: "",
            budget: 0.0,
            windowDays: 0,
            status: StatementProfileStatus.new
        )
    }
}
