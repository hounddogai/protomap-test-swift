import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program summary is in its life cycle.
    enum ProgramSummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A program summary as the program team keeps it.
    final class ProgramSummary {
        var code: String
        var title: String
        var maximum: Double
        var checksum: String
        var version: Int
        var visible: Bool
        var createdAt: Int
        var expiresAt: Int
        var minimum: Double
        var description: String
        var status: ProgramSummaryStatus

        init(code: String, title: String, maximum: Double, checksum: String, version: Int, visible: Bool, createdAt: Int, expiresAt: Int, minimum: Double, description: String, status: ProgramSummaryStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.checksum = checksum
            self.version = version
            self.visible = visible
            self.createdAt = createdAt
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramSummaryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ProgramSummaryStatus.completed || next == ProgramSummaryStatus.cancelled
            case .completed:
                return next == ProgramSummaryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return (minimum * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> ProgramSummary {
            return ProgramSummary(
                code: code,
                title: title,
                maximum: maximum,
                checksum: checksum,
                version: version,
                visible: visible,
                createdAt: createdAt,
                expiresAt: expiresAt,
                minimum: minimum,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a program summary in status planned.
    static func newProgramSummary(_ code: String, title: String) -> ProgramSummary {
        return ProgramSummary(
            code: code,
            title: title,
            maximum: 0.0,
            checksum: "",
            version: 0,
            visible: false,
            createdAt: 0,
            expiresAt: 0,
            minimum: 0.0,
            description: "",
            status: ProgramSummaryStatus.planned
        )
    }
}
