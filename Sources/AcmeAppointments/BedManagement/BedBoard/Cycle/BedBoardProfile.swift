import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board profile is in its life cycle.
    enum BedBoardProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A bed board profile. Its code is unique within a tenant.
    final class BedBoardProfile {
        var code: String
        var name: String
        var revision: Int
        var category: String
        var checksum: String
        var createdAt: Int
        var externalRef: String
        var windowDays: Int
        var summary: String
        var payer: String
        var status: BedBoardProfileStatus

        init(code: String, name: String, revision: Int, category: String, checksum: String, createdAt: Int, externalRef: String, windowDays: Int, summary: String, payer: String, status: BedBoardProfileStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.category = category
            self.checksum = checksum
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.summary = summary
            self.payer = payer
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

        func canMoveTo(_ next: BedBoardProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == BedBoardProfileStatus.draining
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BedBoardProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("bed board profile") \(code)"
        }

        func netTotal() -> Double {
            return (Double(windowDays) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardProfile {
            return BedBoardProfile(
                code: code,
                name: name,
                revision: revision,
                category: category,
                checksum: checksum,
                createdAt: createdAt,
                externalRef: externalRef,
                windowDays: windowDays,
                summary: summary,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a bed board profile in status idle.
    static func newBedBoardProfile(_ code: String, name: String) -> BedBoardProfile {
        return BedBoardProfile(
            code: code,
            name: name,
            revision: 0,
            category: "",
            checksum: "",
            createdAt: 0,
            externalRef: "",
            windowDays: 0,
            summary: "",
            payer: "",
            status: BedBoardProfileStatus.idle
        )
    }
}
