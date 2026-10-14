import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves global bed board manifests through their life cycle and keeps a journal of what it did.
    final class GlobalBedBoardManifestDesk {
        var store: any GlobalBedBoardManifestStore
        var validator: GlobalBedBoardManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalBedBoardManifestEngine

        init(store: any GlobalBedBoardManifestStore, validator: GlobalBedBoardManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalBedBoardManifestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global bed board manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalBedBoardManifestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global bed board manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalBedBoardManifestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global bed board manifest \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newGlobalBedBoardManifestDesk(_ store: any GlobalBedBoardManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalBedBoardManifestDesk {
        return GlobalBedBoardManifestDesk(
            store: store,
            validator: defaultGlobalBedBoardManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalBedBoardManifestEngine(flags)
        )
    }
}
