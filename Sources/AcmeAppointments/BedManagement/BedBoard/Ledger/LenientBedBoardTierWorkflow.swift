import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves lenient bed board tiers through their life cycle and keeps a journal of what it did.
    final class LenientBedBoardTierManager {
        var store: any LenientBedBoardTierStore
        var validator: LenientBedBoardTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientBedBoardTierStore, validator: LenientBedBoardTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient bed board tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientBedBoardTierStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient bed board tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientBedBoardTierStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newLenientBedBoardTierManager(_ store: any LenientBedBoardTierStore, clock: any Kit.Clocks.Clock) -> LenientBedBoardTierManager {
        return LenientBedBoardTierManager(
            store: store,
            validator: defaultLenientBedBoardTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
