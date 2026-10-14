import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board entries through their life cycle and keeps a journal of what it did.
    final class BedBoardEntryWorkflow {
        var store: any BedBoardEntryStore
        var validator: BedBoardEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BedBoardEntryStore, validator: BedBoardEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardEntryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardEntryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newBedBoardEntryWorkflow(_ store: any BedBoardEntryStore, clock: any Kit.Clocks.Clock) -> BedBoardEntryWorkflow {
        return BedBoardEntryWorkflow(
            store: store,
            validator: defaultBedBoardEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
