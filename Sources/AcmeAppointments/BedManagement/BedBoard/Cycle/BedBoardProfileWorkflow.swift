import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board profiles through their life cycle and keeps a journal of what it did.
    final class BedBoardProfileWorkflow {
        var store: any BedBoardProfileStore
        var validator: BedBoardProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardProfileEngine

        init(store: any BedBoardProfileStore, validator: BedBoardProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardProfileEngine) {
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
                throw Kit.Failure("bed board profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board profile \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newBedBoardProfileWorkflow(_ store: any BedBoardProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardProfileWorkflow {
        return BedBoardProfileWorkflow(
            store: store,
            validator: defaultBedBoardProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardProfileEngine(flags)
        )
    }
}
