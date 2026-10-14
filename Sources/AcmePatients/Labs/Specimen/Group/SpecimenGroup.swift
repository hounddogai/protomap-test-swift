import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen group is in its life cycle.
    enum SpecimenGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A specimen group. Its code is unique within a tenant.
    final class SpecimenGroup {
        var code: String
        var name: String
        var title: String
        var ceiling: Double
        var durationMinutes: Int
        var status: SpecimenGroupStatus

        init(code: String, name: String, title: String, ceiling: Double, durationMinutes: Int, status: SpecimenGroupStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenGroupStatus) -> Bool {
            switch status {
            case .requested:
                return next == SpecimenGroupStatus.granted || next == SpecimenGroupStatus.revoked
            case .granted:
                return next == SpecimenGroupStatus.revoked || next == SpecimenGroupStatus.expired
            case .revoked:
                return next == SpecimenGroupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("specimen group") \(code)"
        }

        func weightedTotal() -> Double {
            return (ceiling * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenGroup {
            return SpecimenGroup(
                code: code,
                name: name,
                title: title,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a specimen group in status requested.
    static func newSpecimenGroup(_ code: String, name: String) -> SpecimenGroup {
        return SpecimenGroup(
            code: code,
            name: name,
            title: "",
            ceiling: 0.0,
            durationMinutes: 0,
            status: SpecimenGroupStatus.requested
        )
    }
}
