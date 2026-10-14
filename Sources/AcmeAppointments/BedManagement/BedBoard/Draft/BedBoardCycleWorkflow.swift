import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board cycles through their life cycle and keeps a journal of what it did.
    final class BedBoardCycleManager {
        var store: any BedBoardCycleStore
        var validator: BedBoardCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardCycleEngine

        init(store: any BedBoardCycleStore, validator: BedBoardCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardCycleEngine) {
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
                throw Kit.Failure("bed board cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardCycleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardCycleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board cycle \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newBedBoardCycleManager(_ store: any BedBoardCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardCycleManager {
        return BedBoardCycleManager(
            store: store,
            validator: defaultBedBoardCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardCycleEngine(flags)
        )
    }
}
