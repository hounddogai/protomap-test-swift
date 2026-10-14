import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient shift segment is in its life cycle.
    enum LenientShiftSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient shift segment. Its code is unique within a tenant.
    final class LenientShiftSegment {
        var code: String
        var title: String
        var approved: Bool
        var createdAt: Int
        var refills: Int
        var contactEmail: String
        var attributes: [String: String]
        var ratio: Double
        var status: LenientShiftSegmentStatus

        init(code: String, title: String, approved: Bool, createdAt: Int, refills: Int, contactEmail: String, attributes: [String: String], ratio: Double, status: LenientShiftSegmentStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.createdAt = createdAt
            self.refills = refills
            self.contactEmail = contactEmail
            self.attributes = attributes
            self.ratio = ratio
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

        func canMoveTo(_ next: LenientShiftSegmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LenientShiftSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient shift segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netTotal() -> Double {
            return ((Double(refills) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientShiftSegment {
            return LenientShiftSegment(
                code: code,
                title: title,
                approved: approved,
                createdAt: createdAt,
                refills: refills,
                contactEmail: contactEmail,
                attributes: attributes,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient shift segment in status requested.
    static func newLenientShiftSegment(_ code: String, title: String) -> LenientShiftSegment {
        return LenientShiftSegment(
            code: code,
            title: title,
            approved: false,
            createdAt: 0,
            refills: 0,
            contactEmail: "",
            attributes: [:],
            ratio: 0.0,
            status: LenientShiftSegmentStatus.requested
        )
    }
}
