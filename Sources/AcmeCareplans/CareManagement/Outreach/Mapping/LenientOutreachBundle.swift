import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient outreach bundle is in its life cycle.
    enum LenientOutreachBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a lenient outreach bundle and its current status.
    final class LenientOutreachBundle {
        var code: String
        var name: String
        var tags: [String]
        var checksum: String
        var unit: String
        var visitMinutes: Int
        var createdAt: Int
        var archived: Bool
        var discount: Double
        var status: LenientOutreachBundleStatus

        init(code: String, name: String, tags: [String], checksum: String, unit: String, visitMinutes: Int, createdAt: Int, archived: Bool, discount: Double, status: LenientOutreachBundleStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.checksum = checksum
            self.unit = unit
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.archived = archived
            self.discount = discount
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

        func canMoveTo(_ next: LenientOutreachBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientOutreachBundleStatus.ready || next == LenientOutreachBundleStatus.stopped
            case .warming:
                return next == LenientOutreachBundleStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LenientOutreachBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient outreach bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient outreach bundle") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((Double(createdAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LenientOutreachBundle {
            return LenientOutreachBundle(
                code: code,
                name: name,
                tags: tags,
                checksum: checksum,
                unit: unit,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                archived: archived,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient outreach bundle in status idle.
    static func newLenientOutreachBundle(_ code: String, name: String) -> LenientOutreachBundle {
        return LenientOutreachBundle(
            code: code,
            name: name,
            tags: [],
            checksum: "",
            unit: "",
            visitMinutes: 0,
            createdAt: 0,
            archived: false,
            discount: 0.0,
            status: LenientOutreachBundleStatus.idle
        )
    }
}
