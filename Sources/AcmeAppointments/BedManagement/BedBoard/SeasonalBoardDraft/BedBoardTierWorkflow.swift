import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board tiers through their life cycle and keeps a journal of what it did.
    final class BedBoardTierService {
        var store: any BedBoardTierStore
        var validator: BedBoardTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardTierEngine

        init(store: any BedBoardTierStore, validator: BedBoardTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardTierEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardTierStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardTierStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board tier \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newBedBoardTierService(_ store: any BedBoardTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardTierService {
        return BedBoardTierService(
            store: store,
            validator: defaultBedBoardTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardTierEngine(flags)
        )
    }
}
