import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves lenient inventory digests through their life cycle and keeps a journal of what it did.
    final class LenientInventoryDigestService {
        var store: any LenientInventoryDigestStore
        var validator: LenientInventoryDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientInventoryDigestStore, validator: LenientInventoryDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient inventory digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientInventoryDigestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient inventory digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientInventoryDigestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newLenientInventoryDigestService(_ store: any LenientInventoryDigestStore, clock: any Kit.Clocks.Clock) -> LenientInventoryDigestService {
        return LenientInventoryDigestService(
            store: store,
            validator: defaultLenientInventoryDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
