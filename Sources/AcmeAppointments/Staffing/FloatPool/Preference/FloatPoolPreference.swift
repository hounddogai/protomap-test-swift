import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool preference is in its life cycle.
    enum FloatPoolPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A float pool preference. Its code is unique within a tenant.
    final class FloatPoolPreference {
        var code: String
        var name: String
        var updatedAt: Int
        var tags: [String]
        var createdAt: Int
        var ward: String
        var version: Int
        var durationMinutes: Int
        var specialty: String
        var status: FloatPoolPreferenceStatus

        init(code: String, name: String, updatedAt: Int, tags: [String], createdAt: Int, ward: String, version: Int, durationMinutes: Int, specialty: String, status: FloatPoolPreferenceStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.tags = tags
            self.createdAt = createdAt
            self.ward = ward
            self.version = version
            self.durationMinutes = durationMinutes
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == FloatPoolPreferenceStatus.warming
            case .warming:
                return next == FloatPoolPreferenceStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FloatPoolPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("float pool preference") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((Double(durationMinutes) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolPreference {
            return FloatPoolPreference(
                code: code,
                name: name,
                updatedAt: updatedAt,
                tags: tags,
                createdAt: createdAt,
                ward: ward,
                version: version,
                durationMinutes: durationMinutes,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a float pool preference in status idle.
    static func newFloatPoolPreference(_ code: String, name: String) -> FloatPoolPreference {
        return FloatPoolPreference(
            code: code,
            name: name,
            updatedAt: 0,
            tags: [],
            createdAt: 0,
            ward: "",
            version: 0,
            durationMinutes: 0,
            specialty: "",
            status: FloatPoolPreferenceStatus.idle
        )
    }
}
